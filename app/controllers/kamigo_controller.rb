require 'line/bot'
class KamigoController < ApplicationController
  protect_from_forgery with: :null_session

  def eat
    render plain: "卡米"
  end

  def request_headers
    render plain: request.headers.to_h.reject{|key, value| key.include?('.')}.map{|key, value| "#{key}:#{value}"}.sort.join("\n")
  end

  def request_body
    render plain: request.body
  end

  def response_headers
    response.headers["9527"] = "Y_Y"
    render plain: response.headers.map{ |key, value|
      "#{key}: #{value}"
    }.sort.join("\n")
  end

  def show_response_body
    puts "我在這 \\(￣▽￣)/"
    puts "===這是設定前的response.body:#{response.body}==="
    render plain: "哈哈哈"
    puts "===這是設定後的response.body:#{response.body}==="
  end

  def sent_request
    uri = URI('http://localhost:3000/kamigo/eat')
    http = Net::HTTP.new(uri.host, uri.port)
    http_request = Net::HTTP::Get.new(uri)
    http_response = http.request(http_request)

    render plain: JSON.pretty_generate({
      request_class: request.class,
      response_class: response.class,
      http_request_class: http_request.class,
      http_response_class: http_response.class
    })
  end

  def translate_to_korean(message)
    "#{message}u~"
  end

  def webhook
    # 記錄頻道(find_or_create_by避免相同的資料重複被存導致同一個人收到多次)
    Channel.find_or_create_by(channel_id: channel_id)

    # 學說話
    reply_text = learn(channel_id, received_text)

    # 設定回覆文字
    reply_text = keyword_reply(channel_id, received_text) if reply_text.nil?

    # 重複
    reply_text = echo2(channel_id, received_text) if reply_text.nil?

    # 紀錄
    save_to_received(channel_id, received_text)
    save_to_reply(channel_id, reply_text)

    # 傳送訊息到 line
    response = reply_to_line(reply_text)

    # 回應 200
    head :ok
    
  end

  def learn(channel_id, received_text)
    #如果開頭不是 卡米狗學說話; 就跳出
    return nil unless received_text[0..6] == '卡米狗學說話;'

    received_text = received_text[7..-1]
    semicolon_index = received_text.index(';')

    # 找不到分號就跳出
    return nil if semicolon_index.nil?

    keyword = received_text[0..semicolon_index-1]
    message = received_text[semicolon_index+1..-1]
    KeywordMapping.create(channel_id: channel_id, keyword: keyword, message: message)
    'got it ~'
  end
  
  # Line Bot API 物件初始化
  def line
    # return @line unless @line.nil?  
    @line ||= Line::Bot::Client.new{|config|
      config.channel_secret = '57d1d732a9dd3f02aeee87b3c882a481'
      config.channel_token = 'CvaRq33hjRaTSFurt8t24NPakKRZ7oVLs04nhOTeZydD3CCMpZtTAHcKPEgBoAtnHwt5QuO6i8oxKh6xXwvli+RqOGILUd4qY2AcOLgzbyPb5H7HZdrjn6pAQdYlFcaozRMWUtX9yFoDTXLM6CgEfAdB04t89/1O/w1cDnyilFU='
    }
  end

  # 傳送訊息到 line
  def reply_to_line(reply_text)
    return nil if reply_text.nil?

    # 取得reply token
    reply_token = params['events'][0]['replyToken']

    # 設定回覆訊息
    message = {
      type: 'text',
      text: reply_text
    }

    # 傳送訊息
    line.reply_message(reply_token, message)

  end

  # 取得對方說的話
  def received_text
    message = params['events'][0]['message']
    message['text'] unless message.nil?
  end

  def keyword_reply(channel_id, received_text)
    # 學習紀錄表
    message = KeywordMapping.where(channel_id: channel_id, keyword: received_text).last&.message
    return message unless message.nil?
    KeywordMapping.where(keyword: received_text).last&.message
    
  end

  def channel_id
    source = params['events'][0]['source']
    source['groupId'] || source['roomId'] || source['userId']
  end

  def save_to_received(channel_id, received_text)
    return if received_text.nil?
    Received.create(channel_id: channel_id, text: received_text)  
  end

  def save_to_reply(channel_id, reply_text)
    return if reply_text.nil?
    Reply.create(channel_id: channel_id, text: reply_text)
  end

  def echo2(channel_id, received_text)
    recent_received_texts = Received.where(channel_id: channel_id).last(5)&.pluck(:text)
    return nil unless received_text.in? recent_received_texts
    last_reply_text = Reply.where(channel_id: channel_id).last&.text
    return nil if last_reply_text == received_text
    received_text
  end

end

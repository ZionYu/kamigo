require 'line/bot'
class PushMessagesController < ApplicationController
  before_action :authenticate_user!

  def new
  end

  def create
    text = params[:text]
    Channel.all.each do |channel|
      push_to_line(channel.channel_id, text)
    end
    redirect_to '/push_messages/new'
  end

  def push_to_line(channel_id, text)
    return nil if channel_id.nil? or text.nil?
    
    # 設定回覆訊息
    message = {
      type: 'text',
      text: text
    } 

    # 傳送訊息
    line.push_message(channel_id, message)
  end

  def line
    @line ||= Line::Bot::Client.new { |config|
      config.channel_secret = '57d1d732a9dd3f02aeee87b3c882a481'
      config.channel_token = 'CvaRq33hjRaTSFurt8t24NPakKRZ7oVLs04nhOTeZydD3CCMpZtTAHcKPEgBoAtnHwt5QuO6i8oxKh6xXwvli+RqOGILUd4qY2AcOLgzbyPb5H7HZdrjn6pAQdYlFcaozRMWUtX9yFoDTXLM6CgEfAdB04t89/1O/w1cDnyilFU='
    }
  end

end
require 'line/bot'

class WebhookController < ApplicationController
  protect_from_forgery except: [:callback] # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "2250bc69bac8865396abbe8b6086632e"
      config.channel_token = "huLMDPpMa+A/GT0/WJZNA3lZvDjOBhYjIxSRzehEmiTZm74esUoRzg0R+ug/A1C7NwuGTpJpOozlribUhYXv40LjEPRw1+Vd23qwADllzWyhezcTtJ7kGADZcbLz4WUvMuxS8wDediB1bLm8GFv36QdB04t89/1O/w1cDnyilFU="
    }
  end

  def message_for_menu?(msg)
    msg == "メニュー"
  end

  def message_for_done?(msg)
    msg == "やった"
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head 470
    end 

    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text

          received_msg = event.message['text']
          today = Date.today
          muscle_training_menu = [
            "腹筋20回×3セット！",
            "腕立て伏せ30回×3セット！",
            "腹筋&腕立て伏せ20回ずつ×3セット",
            "ランニング！雨が降っていれば、休み。",
            "スクワット100回×1セット！",
            "背筋30回×2セット！",
            "まあ、たまには休んでもいいだろう。"
          ]

          #すでにデータがある場合、最新の筋トレ記録を取得する
          if Training.any?
            latest_training = Training.order('created_at DESC').first
            latest_training_date = latest_training.created_at
          #まだデータがない場合は、最近トレーニングした日を昨日とする。
          else
            latest_training_date = Date.prev_day
          end
          
          #まだ今日のメニューをもらっていない場合
          if not latest_training_date.today?
            #「メニュー」と送ってきた場合、今日のメニューをランダムに作成
            if message_for_menu?(received_msg)
              response_for_menu = muscle_training_menu.sample
              training = Training.create(menu:response_for_menu)
            
            #「やった」と送ってきた場合
            elsif message_for_done?(received_msg)
              response_for_menu = "先にメニューを選んでください！"
            end    

          #すでに今日の筋トレメニューをもらっている場合
          else

            #「メニュー」と送ってきた場合
            if message_for_menu?(received_msg)
              response_for_menu = muscle_training_menu.sample
              latest_training.menu = response_for_menu
            
            #「やった」
            elsif message_for_done?(received_msg)
              response_for_done = "お疲れさまです"
              latest_training.done = true
            end

          end

          if response_for_menu.present?
            message = {
              type: 'text',
              text: response_for_menu
            }
          elsif response_for_done.present?
            message = {
              type: 'text',
              text: response_for_done
            } 
          end

          client.reply_message(event['replyToken'], message)

        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      end
    }
    head :ok
  end
end
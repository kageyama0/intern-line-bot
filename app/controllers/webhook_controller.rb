require 'line/bot'
#require 'date'

class WebhookController < ApplicationController
  protect_from_forgery except: [:callback] # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
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
          #最新の筋トレ記録を取得する
          @latest_training = Training.find_by(id: Training.count)
          @latest_training_date = Date.parse(String(@latest_training.created_at).split()[0])

          #今日の日付
          @today = Date.parse(String(Time.current).split()[0])


          #まだ今日のメニューをもらっていない場合
          if @latest_training_date < @today 
            #「メニュー」と送ってきた場合、今日のメニューをランダムに作成
            if event.message['text'] == "メニュー"
              menu = [
                "腹筋20回×3セット！",
                "腕立て伏せ30回×3セット！",
                "腹筋&腕立て伏せ20回ずつ×3セット",
                "ランニング！雨が降っていれば、休み。",
                "スクワット100回×1セット！",
                "背筋30回×2セット！",
                "まあ、たまには休んでもいいだろう。"
              ]
              response1 = menu.sample
              @training = Training.create(menu:response1)
            
            #「やった」or「done」と送ってきた場合
            elsif event.message['text'] == "やった" or event.message['text'] == "done"
              response2 = "先にメニューを選んでください！"

            end    

          #すでに今日の筋トレメニューをもらっている場合
          else

            #「メニュー」と送ってきた場合
            if event.message['text'] == "メニュー"
              response1 = menu.sample
              @training.menu = response1
            
            #「やった」or「done」
            elsif event.message['text'] == "やった" or event.message['text'] == "done"
              response2 = "お疲れさまです"
              response1 = ""
            end

          end

          if response1.present?
            message = {
              type: 'text',
              text: response1
            }
          elsif response2.present?
            message = {
              type: 'text',
              text: response2
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
require 'line/bot'

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

          @today = Date.today

          muscle_training_menu = [
            "腹筋20回×3セット！",
            "腕立て伏せ30回×3セット！",
            "腹筋&腕立て伏せ20回ずつ×3セット",
            "ランニング！雨が降っていれば、休み。",
            "スクワット100回×1セット！",
            "背筋30回×2セット！",
            "まあ、たまには休んでもいいだろう。"
          ]

          #まだ今日のメニューをもらっていない場合
          if @latest_training_date < @today 
            #「メニュー」と送ってきた場合、今日のメニューをランダムに作成
            if event.message['text'] == "メニュー"
              response_for_menu = muscle_training_menu.sample
              @training = Training.create(menu:response_for_menu)
            
            #「やった」or「done」と送ってきた場合
            elsif event.message['text'] == "やった" or event.message['text'] == "done"
              response_for_menu = "先にメニューを選んでください！"
            end    

          #すでに今日の筋トレメニューをもらっている場合
          else

            #「メニュー」と送ってきた場合
            if event.message['text'] == "メニュー"
              response_for_menu = muscle_training_menu.sample
              @latest_training.menu = response_for_menu
            
            #「やった」or「done」
            elsif event.message['text'] == "やった" or event.message['text'] == "done"
              response_for_done = "お疲れさまです"
              @latest_training.check = true
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
          client.push_message(ENV['LINE_GROUP_ID'],message)

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
require 'line/bot'

class WebhookController < ApplicationController
  protect_from_forgery except: [:callback] # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
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
          muscle_training_menu = [
            "腹筋20回×3セット！",
            "腕立て伏せ30回×3セット！",
            "腹筋&腕立て伏せ20回ずつ×3セット",
            "ランニング！雨が降っていれば、休み。",
            "スクワット100回×1セット！",
            "背筋30回×2セット！",
            "まあ、たまには休んでもいいだろう。"
          ]

          #今日与えられた筋トレメニューのデータがあれば...
          today_range = Date.today.beginning_of_day..Date.today.end_of_day  
          training_of_today = Training.where(created_at: today_range).first

          #鬼畜モード(10minに一回筋トレしたかチェック)
          # tenminpast = Time.now - 1
          # tenminutes_range = tenminpast..Time.now
          # training_of_today = Training.where(created_at: tenminutes_range).first

          #まだ今日のメニューをもらっていない場合
          if training_of_today.blank?
            #「メニュー」と送ってきた場合、今日のメニューをランダムに作成
            if message_for_menu?(received_msg)
              response = muscle_training_menu.sample
              training = Training.create(menu:response)
            
            #「やった」と送ってきた場合
            elsif message_for_done?(received_msg)
              response = "先にメニューを選んでください！"
            end    

          #すでに今日の筋トレメニューをもらっている場合
          else

            #「メニュー」と送ってきた場合
            if message_for_menu?(received_msg)
              response = muscle_training_menu.sample
              training_of_today.update(menu: response)
            
            #「やった」
            elsif message_for_done?(received_msg)
              response = "お疲れさまです"
              training_of_today.update(done: true)
            end

          end

          #「記録」
          if received_msg == '記録'
            a_week_ago = Date.today - 7
            training_of_week = Training.where("created_at > ?",a_week_ago)
            response = ""
            training_of_week.each do |t|
              response += t.created_at.strftime('%Y年%m月%d日 %H:%M') + ":" + t.menu + "\n"
            end
          end

          message = {
            type: 'text',
            text: response
          } 

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
desc "This task is called by the Heroku scheduler add-on"
task :send_penalty => :environment do
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  puts 'try to send a penalty_message'

  #通常モード
  today_range = Date.today.beginning_of_day..Date.today.end_of_day
  #鬼畜モード
  tenminpast = Time.now - 600
  tenminutes_range = tenminpast..Time.now
  
  training_of_today = Training.where(created_at: tenminutes_range).first
  p training_of_today

  if training_of_today.blank?
    penalty_messages = [
      '〇〇です。筋トレ失敗…先着１名様に昼食おごります…',
      '〇〇です。筋トレ失敗しました…先着３名様に飲み物おごります…',
      '〇〇です。筋トレ失敗…でもまあ今日はおごらなくてもいいかな、うん'
    ]
    penalty_message = penalty_messages.sample
    p_msg = {
      type: 'text',
      text: penalty_message
    } 
  else
    p_msg = {
      type: 'text',
      text: '〇〇です。筋トレしました！'
    }
  end

  client.push_message(ENV['LINE_GROUP_ID'], p_msg)

  puts 'Sending a message is completed.'

end

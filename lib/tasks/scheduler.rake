desc "This task is called by the Heroku scheduler add-on"
task :send_penalty => :environment do
  puts 'try to send a penalty_message'
  penalty_messages = [
  '筋トレ失敗…先着１名様に昼食おごります…',
  '筋トレ失敗…先着３名様に飲み物おごります…',
  '筋トレ失敗…でもまあ今日はおごらなくてもいいかな、うん'
  ]
  penalty_message = penalty_messages.sample

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV['LINE_CHANNEL_SECRET']
    config.channel_token = ENV['LINE_CHANNEL_TOKEN']
  }
  client.push_message(ENV['LINE_GROUP_ID'], penalty_message)

  latest_training = Training.order('created_at DESC').first

  if latest_training.created_at < Time.current
    client.push_message(ENV['LINE_GROUP_ID'], penalty_message)
  end

  puts 'Sending a message is completed.'

end

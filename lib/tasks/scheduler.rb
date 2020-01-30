desc "This task is called by the Heroku scheduler add-on"
task :send_penalty => :environment do
  puts "Sending penalty message to group..."
  latest_training = Training.order('created_at DESC').first
  penalty_messages = [
    "筋トレ失敗…先着１名様に昼食おごります…",
    "筋トレ失敗…先着３名様に飲み物おごります…",
    "筋トレ失敗…でもまあ今日はおごらなくてもいいかな、うん"
  ]
  if not latest_training.done?
    client.push_message(ENV['LINE_GROUP_ID'],message)
  end
  puts "Sending a message is completed."
end
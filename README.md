## **こだわったところ、工夫したところ**

**作った動機：**今まで筋トレが続いたことがなかったので(最高一週間)、それを克服するためのものを作ろうと思いました。

**仕様:**

「メニュー」=> 筋トレメニューを事前に設定した下記のメニューの中からランダムに選んで教えてくれる。

    muscle_training_menu = [
                "腹筋20回×3セット！",
                "腕立て伏せ30回×3セット！",
                "腹筋&腕立て伏せ20回ずつ×3セット",
                "ランニング！雨が降っていれば、休み。",
                "スクワット100回×1セット！",
                "背筋30回×2セット！",
                "まあ、たまには休んでもいいだろう。"
              ]

「やった」=> その日に筋トレをやっていれば「お疲れ様でした。」=> そうでなければ、「先にメニューを選んでください。」と返ってきます。

![https://s3-us-west-2.amazonaws.com/secure.notion-static.com/bf5ef9e3-5140-4097-b402-385650a74b30/Screenshot_20200131-170414_LINE.jpg](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/bf5ef9e3-5140-4097-b402-385650a74b30/Screenshot_20200131-170414_LINE.jpg)

**「記録」**=>直近一週間で何のメニューをしたか確かめる。

![https://s3-us-west-2.amazonaws.com/secure.notion-static.com/d92d31e7-bb1c-42b3-8bde-8afd503771e1/Screenshot_20200131-171844_LINE.jpg](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/d92d31e7-bb1c-42b3-8bde-8afd503771e1/Screenshot_20200131-171844_LINE.jpg)

**「連続日数」**時間が足りず、実装できませんでした....

・ペナルティ筋トレをやらなかったとき、下記の項目の中からペナルティが課されます。

    penalty_messages = [
        '…先着１名様に昼食おごります…',
        '…先着３名様に飲み物おごります…',
        '…今日から一週間以内にサボった場合、毎回ペナルティが３倍になる！！',
        '…でも今日はペナルティなし！'
      ]

![https://s3-us-west-2.amazonaws.com/secure.notion-static.com/b5f018c7-e56b-41f7-b058-4eb96eda3669/Screenshot_20200131-142018_LINE.jpg](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/b5f018c7-e56b-41f7-b058-4eb96eda3669/Screenshot_20200131-142018_LINE.jpg)

## **苦労したところ、頑張ったところ**

・シンプルに環境構築が大変だった。rbenvとrubyのバージョンが揃わずに苦労したりとか...

・そもそもrailsを全然触ったことがなく、progateを直前に一週しただけだったので、少し苦労しました。

・railsがv4のときに作られたコードを改良して作っていたことで起こるエラーに遭遇し、２.3時間ほど迷走していました。メンターの風間さんに助けてもらってなんとかなったんですが、次にインターンで同じ課題をやる人がもしDBを使う場合は同じところで詰まると思うので、前もって教えてあげてほしいです。

・今日トレーニングしたかどうかを判定するという仕様にしたのが面倒くさかったです。日付が変わるまで待つわけにもいかないので、うまく出来たかどうか検証するのが大変でした。10分おきに筋トレしたかどうかチェックする鬼畜モードを別に作って検証したりしていました。




# 前提
- [Heroku](https://jp.heroku.com/) のアカウントを取得済みであること。
- Herokuの[CLIツール](https://devcenter.heroku.com/articles/getting-started-with-ruby#set-up)がインストール済みであること。
- [LINE Developer](https://developers.line.me/ja/) 登録が完了し、プロバイダー・channelの作成が完了していること。

# 環境
```
$ ruby -v
ruby 2.4.0p0 (2016-12-24 revision 57164) [x86_64-darwin16]

$ bundle exec rails -v
Rails 5.1.4
```

# Webhook環境の構築
1. リポジトリをクローンする。
```
git clone git@github.com:giftee/intern-line-bot.git
```

2. Herokuにログインする。
```
$ heroku login
heroku: Press any key to open up the browser to login or q to exit:
```

3. heroku上にアプリを作成する。
```
$ heroku create
Creating app... done, ⬢ XXXXX    // XXXXX はランダムな文字列が生成される。
https://XXXXX.herokuapp.com/ | https://git.heroku.com/XXXXX.git

$ git remote -v
heroku	https://git.heroku.com/XXXXX.git (fetch)
heroku	https://git.heroku.com/XXXXX.git (push)
origin	git@github.com:giftee/intern-line-bot.git (fetch)
origin	git@github.com:giftee/intern-line-bot.git (push)
```

4. herokuに資源をデプロイする。
```
$ git push heroku master
```

5. heroku上にアプリが公開されたか確認する。
```
$ heroku open
```

6. LINE Messaging APIにアクセスするためのシークレット情報を登録する。
LINE developer コンソールのChannel基本設定から「Channel Secret」と「アクセストークン」を取得し、以下の通り設定する。
```
$ heroku config:set LINE_CHANNEL_SECRET=*****
$ heroku config:set LINE_CHANNEL_TOKEN=*****
```

# LINE Developerコンソールの設定
LINE DeveloperコンソールのChannel基本設定から、以下を設定。

- Webhook送信: 利用する
- Webhook URL: https://XXXXX.herokuapp.com/callback
- Botのグループトーク参加: 利用する
- 自動応答メッセージ: 利用しない
- 友だち追加時あいさつ: 利用する

※Webhook URLの `https://XXXXX.herokuapp.com` には `heroku create` で生成されたURLを指定する。Webhook URLを設定した後に接続確認ボタンを押して成功したら疎通完了。

# Q&A
## Q. herokuのログが見たい
```
$ heroku logs --tail
```

## Q. masterブランチ以外をherokuにデプロイしたい
```
$ git push heroku (branch名):master -f
```

# 参考
ローカル環境構築は[こちら](https://github.com/giftee/intern-line-bot/wiki/%E3%83%AD%E3%83%BC%E3%82%AB%E3%83%AB%E7%92%B0%E5%A2%83%E6%A7%8B%E7%AF%89)

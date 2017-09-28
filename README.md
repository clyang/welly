Welly - clyang edition
=============

Introduction / 簡介
-------------

Welly is a terminal application on Mac OS X, which aims to bring best user experience for browsing term BBS. My edition is based on @KOed 's great work. This edition provides new features and bug fixes reported by users.

***

Welly是一套運行在Mac上功能豐富的BBS軟體, 我所維護的版本是基於 @KOed 的版本之上, 做進一步的功能開發以及bug修復.

Download latest version / 下載最新版
-------------
Welly - clyang edition: [v.2.9.6](https://github.com/clyang/welly/releases/tag/2.9.6)

Features / 主要功能
-------------
1. telnet to BBS via Websocket Secure (wss://)
   - Your plain password won't be seen by others!
   - Bypass annony blocking on Port 22 or 23.
2. auto-login by wss://
3. bundle telnet within Welly
   - High Sierra has remove `telnet` command by default. Having this helps users on High Sierra (new purchase/clean install) enjoying BBS again
4. provide "command+p" hotkey
   - Fetch and open PTT's post direct URL link automatically. Extremely userful for the post which contains a lot of image links.
5. provide "Long Comment" function
   - The user can focus on leaving long comments on specific article without worrying the system limitation.
6. Auto update
   - Always get the up-to-date version of Welly!
7. Support Full Screen mode

***

1. 使用Websocket Secure方式連線至ptt
   - 您寶貴的密碼再也不會在網路上裸奔啦.
   - 出門在外再也不用擔心連接阜22跟23被擋了.
2. wss:// 支援自動登入功能
3. 內嵌 `telnet` 程式
   - High Sierra預設是將 `telnet` 程式移除的, 如果使用者是全新購買Mac或是重新安裝High Sierra, 將無法正常使用telnet, 這功能將完美的解決這個問題.
4. 一鍵開啟網頁版文章 ( `command+p` )
   - 在文章列表或閱讀文章時, 按command+p即可用瀏覽器開啟該篇的網頁版, 對於圖片很多的文章特別好用!
5. 自動分段推文 ( `command+m` )
   - 您終於可以在Mac上推文時暢所欲言了, 您只需要專注在推文內容, 推文長度這種討人厭的事情就交給Welly來處理!
6. 自動更新
   - 最即時的取得最新版的Welly
7. 全螢幕瀏覽BBS
   - 給你滿滿的大螢幕版BBS!

Project Dependency / 程式相依性
-------------

In order to make telnet protocol work via Websocket Secure (wss://), a tiny program called `usock2wsock` is included. You can get and build your own binary from [Go-UnixSocket2WebSocket](https://github.com/clyang/Go-UnixSocket2WebSocket).

***

此版本的Welly提供了Websocket Secure (wss://)的功能, 因此Welly內包含了一隻叫做`usock2wsock`的小程式, 您也可以從 [Go-UnixSocket2WebSocket](https://github.com/clyang/Go-UnixSocket2WebSocket) 這邊取得原始碼並且自行編譯.

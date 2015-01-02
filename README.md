Keystats [![Build Status](https://travis-ci.org/ElDeveloper/keystats.svg?branch=master)](https://travis-ci.org/ElDeveloper/keystats)
====================================================================================================================================

A simple key logger for OS X.

![Screenshot](http://i.imgur.com/if86zIn.gif)

### Features

- Logs every keystroke into a `sqlite3` database.
- Shows total number of registered keystrokes in the database.
- Shows daily, weekly and monthly stats.
- Shows the date of the earliest registered keystroke.
- Registers time, keycode, ASCII value and the "front most" application's
bundle identifier (`Safari` -> `com.apple.Safari`).
- Shows a plot with the number of keystrokes per day in the past 29 days.
- Click on the bars to get the full date it represents.

### Icon

![Keystats Icon](http://i.imgur.com/uapDrb3.png)

### Installation and usage.

Find and download the latest release version
[here](https://github.com/ElDeveloper/keystats/releases). Copy the application
to your Applications folder and open it. If this is the first time you open
Keysts, follow the instructions to provide Keystats with accessibility features
and relaunch it. **Note that every time you update Keystas, you will have to
follow these steps agin**

![Installation](http://i.imgur.com/kHSAD67.gif)

### License

Keystats is released under the MIT license.

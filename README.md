# poststats [![Codacy Badge](https://api.codacy.com/project/badge/Grade/9f54350a80c74d45bce11633aa50629d)](https://www.codacy.com/app/jpylypiw/poststats?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=jpylypiw/poststats&amp;utm_campaign=Badge_Grade) [![version](https://img.shields.io/badge/version-1.1.0-green.svg)](https://github.com/jpylypiw/poststats)

Nearly every **Linux Server** owner is running his own **Postfix Mailserver**. Securely sending emails becomes more and more complicated over time. **Statistics** on the Postfix Mailserver can currently only be accessed via **Mailgraph**. We provide an alternative presentation by **e-mail**. The software is developed in **Bash** for performance reasons and is very easy to install. We are looking forward to your feedback!

## Features

- **Reading multiple Log Files**
- **Modern HTML Template**
- **Superfast written in BASH**
- **Reading files with grep instead of line by line**

## Install

1. Clone repository using `git clone https://github.com/jpylypiw/poststats.git` or download whole repository into a previously created folder using `wget https://github.com/jpylypiw/poststats/archive/master.zip && unzip master.zip`
1. Copy configuration Example to configuration file using `cp poststats.cfg.example poststats.cfg`
1. Edit configuration file. You can find instructions in configuration file.
1. Create Crontab for your favorite user. The user needs read permission on the logfiles provided in configuration file. A sample crontab could look like:

```sh
0 6 * * * /bin/bash /opt/poststats/poststats.sh >/dev/null 2>&1
```

## License

poststats is licensed under the MIT License.

It is not using any 3rd Party Tools. Please check its [License](https://github.com/jpylypiw/poststats/blob/master/LICENSE).

## Screenshots

![Screenshot 1: Responsive HTML E-Mail with Statistics](https://i.imgur.com/1IjtosB.png)

## Changelog

### 1.1.0 (2019-12-29)

Features:

- Changed from MIT to GPL-3 license
- checked the shellscript using shellcheck
- moved the html template from a shell file to a html file for a improved editing experience
- changed configuration example:
  - added first rotated file to file check list (got a empty email on sunday because the logfile was already rotated)
  - added a space between name and email address (rspamd complained about R_NO_SPACE_IN_FROM)
- added rspamd logfile and count of action types

Bugfixes:

- IP address lookup was only searching for interface eth0 and is searching for all interfaces now
- using grep for process searching was very ineffective. I switched to pgrep which brings a better result

### 1.0.0 (2017-12-16)

Features:

- First Commit
- Project Initialization
- Add E-Mail Template
- Add Configuration
- Add Codacy Check
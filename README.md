# rails_cleaner
<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=VKY8YAWAS5XRQ&lc=CA&item_name=Weston%20Ganger&item_number=rails_cleaner&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHostedGuest" target="_blank" title="Buy Me A Coffee"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif" alt="Buy Me A Coffee"/></a>

## Features

- Locate unused partials
- Locate unused database tables
- Locate unused database table columns
- Convert old ruby hash syntax to 1.9+ syntax (:foo => 'bar' changes to foo: 'bar') (Can be used in any ruby project)
- Convert old ruby hash syntax to 2.1+ syntax ('data-width' => 500 changes to 'data-width': 500) (Can be used in any ruby project)

```
rails_cleaner # will run all locate methods in current directory

rails_cleaner --partials --tables --columns my_app/

rails_cleaner --convert --syntax 1.9 my_app/ #outputs changed files

rails_cleaner --convert --syntax 2.1 my_app/ #outputs changes files
```

## Install

```
gem install rails_cleaner
```

# Credits
Created by Weston Ganger - @westonganger

<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=VKY8YAWAS5XRQ&lc=CA&item_name=Weston%20Ganger&item_number=rails_cleaner&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHostedGuest" target="_blank" title="Buy Me A Coffee"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif" alt="Buy Me A Coffee"/></a>

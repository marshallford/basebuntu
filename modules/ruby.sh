# Ruby

# https://gorails.com/deploy/ubuntu/14.04
# Upgrade instructions...
# 1. run > rvm get stable
# 2. run to find availabe versions > list known
# 3. run > rvm upgrade [ruby version here]
# 4. answer yes to all questions
# 5. run to upgrade gems if you wish > rvm all do gem update
function installRuby {
    scriptLocation
    installer ruby-dependencies "libgdbm-dev libncurses5-dev automake libtool bison libffi-dev"
    curl -L https://get.rvm.io | bash -s stable
    source ~/.rvm/scripts/rvm
    rvm install $RUBY
    rvm use $RUBY --default
    ruby -v
    echo "gem: --no-ri --no-rdoc" > ~/.gemrc
    gem install bundler
}

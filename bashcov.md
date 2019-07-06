# bashcov

## sources

```txt
https://github.com/infertux/bashcov
```

## install

- do will you need ruby

```bash
# exclude coverage from your git
if grep coverage .gitignore; then echo ok;else echo "coverage" >>.gitignore;fi;
gem install bashcov
# set alias
alias bashcov="~/.gem/ruby/2.6.0/bin/bashcov"
# call
bashcov
```

## run script with parameter

- write a wrapper script with all parameter and execute

```bash
bashcov <wrapper_script.sh>
```

## exclude file from coverage

```bash
bashcov --skip-uncovered <wrapper_script.sh>
```

## call generated report

```bash
chromium  coverage/index.html
```

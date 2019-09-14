


# echo GREP looking for adcore package:
# grep ^adcore $packages_config

# echo GREP looking for foo package:
# grep ^foo $packages_config

# one option line per section
# echo
# echo AWK looking for adcore package:
# p=adcore
# awk "/^$p[[:space:]]+NAME/ { print \$3; }" $packages_config

# multiple option lines per section
# echo
# echo AWK looking for busy package:
# p=busy
# awk "/^$p[[:space:]]+TAGG/ { \$1=\$2=\"\"; print \$0; }" $packages_config



function test1() {

  echo
  echo -n 'name of ASYN: '
  name asyn
  echo
  echo -n 'repo of ASYN: '
  repo asyn
  echo
  echo -n 'remote of ASYN: '
  remote asyn
  echo
  echo -n 'tags of ASYN:'
  for t in $(tag asyn)
  do
    echo -n " $t"
  done
  echo

  echo
  echo -n 'branches of ADCORE:'
  for t in $(branch adcore)
  do
    echo -n " $t"
  done
  echo

  echo
  echo -n 'path of ADCORE: '
  path adcore

  echo
  echo -n 'chain of BAR:'
  for t in $(chain bar)
  do
    echo -n " $t"
  done
  echo
}



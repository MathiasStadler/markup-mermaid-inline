#!/usr/bin/env bats

load assert
load test_helper
fixtures bats

setup() {
    echo "# --- TEST FILE IS $(basename ${BATS_TEST_FILENAME})" >&3
}


@test 'foo in a' { #empty 
}
@test '--bar in a' { }
@test 'baz in a' { }

@test "truth" {
  skip
  true
}

@test "more truth" {
  true
}

@test "quasi-truth" {
  [ -z "$FLUNK" ]
}

@test "setting a variable" {
  variable=1
  [ $variable -eq 1 ]
}

@test "$SUITE: test with variable in name" {
  true
}

@test "a skipped test with a reason" {
  skip "for a really good reason"
}

@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}

@test "ls" {
  result="$(pwd|echo $?)"
  [ "$result" -eq 0 ]
}





@test "no arguments prints message and usage instructions" {
  run ls
  [ $status -eq 0 ]
#  [ "${lines[0]}" == 'Error: Must specify at least one <test>' ]
#  [ "${lines[1]%% *}" == 'Usage:' ]
}


@test 'test-a' {
  run bash -c 'echo ERROR; false'
  echo "status = ${status}"
  echo "output = ${output}"
  [ "$status" -eq 1 ]
}

@test 'test-a' {
  run bash -c 'echo ERROR; false'
  echo "status = ${status}"
  echo "output = ${output}"
  [ "$status" -eq 1 ]
}

@test 'ps aux' {
  run bash -c 'ps aux'
  echo "status = ${status}"
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test 'false' {
  run bash -c 'false'
  echo "status = ${status}"
  echo "output = ${output}"
  [ "$status" -eq 1 ]
}

@test 'true' {
  run bash -c 'true'
  echo "status = ${status}"
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test 'assert_output()' {
  run echo 'have'
  assert_output 'have'
}

@test 'assert_output() regular expression matching' {
  run echo 'Foobar v0.1.0'
  assert_output --regexp '^Foobar v[0-9]+\.[0-9]+\.[0-9]$'
}

#!/usr/bin/env bats

load error
load output
load assert
load test_helper

fixtures bats

setup() {
    
    echo "# --- TEST NAME IS $(basename ${BATS_TEST_FILENAME})" >&3
    
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

@test 'markdown_mermaid without parameter' {
  run $PWD/inline_mermaid.sh
  echo "status = ${status}"
  echo "output = ${output}"
  [ "$status" -eq 1 ]
}

@test 'Input file missing' {
  regex='^.*Input file missing.*$'
  run $PWD/inline_mermaid.sh -f --input
  echo "status = ${status}"
  echo "output = ${output}"
  [ "$status" -eq 1 ]
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'wrong Input file' {
  regex='^.*Input file not available.*$'
  run $PWD/inline_mermaid.sh -f --input wrong_file.md
  echo "status = ${status}"
  echo "output = ${output}"
  [ "$status" -eq 1 ]
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'output file available and --force not set' {
  regex="^.*ERROR.*file exists.*$"
  # prepare test generate valid version
  run $PWD/inline_mermaid.sh --force --input README.md
  # test
  run $PWD/inline_mermaid.sh --input README.md
  echo "status = ${status}"
  echo "output = ${output}"
  [ "$status" -eq 1 ]
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'delete output by hand and run' {
  regex="^.*successful finished.*$"
  run bash -c 'rm -rf output'
  assert_success
  run $PWD/inline_mermaid.sh --input README.md
  echo "status = ${status}"
  echo "output = ${output}"
  [ "$status" -eq 0 ]
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'markdown_mermaid run successful finished' {
  regex="^.*successful finished.*$"
  run $PWD/inline_mermaid.sh -f --input README.md
  echo "status = ${status}"
  echo "output = ${output}"
  assert_success
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'call with  incorrect-parameter option' {
  regex="^.*option.*NOT FOUND.*$"
  run $PWD/inline_mermaid.sh -f --incorrect-parameter --input README.md
  echo "status = ${status}"
  echo "output = ${output}"
  assert_failure
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'call without any option' {
  regex="^.*usage.*$"
  run $PWD/inline_mermaid.sh
  echo "status = ${status}"
  echo "output = ${output}"
  assert_failure
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'set output file with md' {
  test_output_name="README_OUTPUT.md";
  test_output_name_expected="${test_output_name}"
  regex="^.*${test_output_name_expected}.*$"
  run $PWD/inline_mermaid.sh -f --input README.md --output ${test_output_name}
  echo "status = ${status}"
  echo "output = ${output}"
  assert_success
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'set output file without md' {
  test_output_name="README_OUTPUT";
  test_output_name_expected="${test_output_name}"
  test_output_name_expected+=".mermaid_replace.md"
  regex="^.*${test_output_name_expected}.*$"
  run $PWD/inline_mermaid.sh -f --input README.md --output ${test_output_name}
  echo "status = ${status}"
  echo "output = ${output}"
  assert_success
  echo "${lines[0]}" | assert_output --regexp "$regex"
}


@test 'output file missing' {
  regex="^.*ERROR: Output file is missing.*$"
  run $PWD/inline_mermaid.sh -f --input README.md --output 
  echo "status = ${status}"
  echo "output = ${output}"
  assert_failure
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'set all long option' {
  _input_name="README.md";
  _output_name="${_output_name}"
  _output_name+=".mermaid_replace.md"
  regex="^.*${_output_name}.*$"
  run $PWD/inline_mermaid.sh --verbose --force --input ${_input_name} --output ${_output_name}
  echo "_input_name = ${_input_name}"
  echo "_output_name = ${_output_name}"
  echo "status = ${status}"
  echo "output = ${output}"
  assert_success
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'set all short option' {
  test_output_name="README_OUTPUT";
  test_output_name_expected="${test_output_name}"
  test_output_name_expected+=".mermaid_replace.md"
  regex="^.*${test_output_name_expected}.*$"
  run $PWD/inline_mermaid.sh -v -f -i README.md -o ${test_output_name}
  echo "status = ${status}"
  echo "output = ${output}"
  assert_success
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'double flowchart name in input markdown file' {
  regex="^.*flowchart name.*already in used.*$"
  _input_file="test/test-file/mermaid-double-diagram-name.md"
  _output_file="output/"
  _output_file+="${_input_file}";
  _output_file+=".mermaid_replace.md"

  # output/test/test-file/mermaid-double-diagram-name.mermaid_replace.md
  # setup test
  run bash -c "rm $PWD/${_output_file}"
  # run test
  run $PWD/inline_mermaid.sh -i "${_input_file}"
  echo "_input_file = ${_input_file}"
  echo "_output_file = ${_output_file}"
  echo "status = ${status}"
  echo "output = ${output}"
  assert_failure
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'block error without flavor' {
  regex="^.*ERROR: source block has nor flavor line*$"
  run $PWD/inline_mermaid.sh -f -i test/test-file/mermaid-block-without-flavor.md
  echo "status = ${status}"
  echo "output = ${output}"
  assert_failure
  # echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'mermaid file exits already' {
  regex="^.*ERROR: flowchart name.*already in used.*$";
  _input_file="test/test-file/mermaid-file-exits-already.md";
  _output_file="output/test/test-file/mermaid-file-exits-already.mermaid_replace.md";
  
  # run test
  run ${PWD}/inline_mermaid.sh -i ${PWD}/${_input_file}
  
  echo "_input_file = ${_input_file}"
  echo "_output_file = ${_output_file}"
  echo "status = ${status}"
  echo "output = ${output}"
  assert_failure
  echo "${lines[0]}" | assert_output --regexp "$regex"
}

@test 'mermaid file name missing' {
  regex="^.*ERROR: Please enter the filename after the mermaid block tag line.*$"
  run $PWD/inline_mermaid.sh -f -i test/test-file/mermaid-file-name-missing.md
  echo "status = ${status}"
  echo "output = ${output}"
  assert_failure
  echo "${lines[0]}" | assert_output --regexp "$regex"
}
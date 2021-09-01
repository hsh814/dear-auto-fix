#!/bin/bash

die() {
  echo "$@" >&2
  exit 1
}

USAGE="$0 D4J_HOME BUGGY_LINES_DIR OUTPUT_FILE.tex"
[ $# = 3 ] || die $USAGE

D4J_HOME=$1
BUGGY_LINES_DIR=$2
OUTPUT_FILE=$3

N_FAULTS=357
N_SINGLE_LINE_FAULTS=0
N_MULTILINE_FAULTS=0
N_FAULTS_WITH_OMISSIONS=0
N_FAULTS_WITH_ONLY_OMISSIONS=0

for PROJECT in Chart Closure Lang Math Time; do
  for PATCH_FILE in $D4J_HOME/framework/projects/$PROJECT/patches/*.src.patch; do
    BUG=$(sed 's .*/\([0-9]*\).src.patch \1 ' <<< $PATCH_FILE)
    [ $BUG -lt 1000 ] || continue

    N_LINES_ADDED=$(egrep '^[+]' "$PATCH_FILE" | tail -n +2 | wc -l)
    N_LINES_DELETED=$(egrep '^[-]' "$PATCH_FILE" | tail -n +2 | wc -l)
    if [ $N_LINES_ADDED = 1 ] && [ $N_LINES_DELETED = 1 ]; then
      ((N_SINGLE_LINE_FAULTS++))
    else
      ((N_MULTILINE_FAULTS++))
    fi

    if grep -q '#FAULT_OF_OMISSION' "$BUGGY_LINES_DIR/$PROJECT-$BUG.buggy.lines"; then
      ((N_FAULTS_WITH_OMISSIONS++))
    fi

    if ! grep -vq '#FAULT_OF_OMISSION' "$BUGGY_LINES_DIR/$PROJECT-$BUG.buggy.lines"; then
      ((N_FAULTS_WITH_ONLY_OMISSIONS++))
    fi

  done
done

write_to_macro_file() {
  echo "$@" >> "$OUTPUT_FILE"
}

rm -f "$OUTPUT_FILE"

write_to_macro_file "%% These macros were automatically generated by ${BASH_SOURCE[0]} ."
write_to_macro_file '%% They need to be regenerated if the patches in D4J change,'
write_to_macro_file '%% but `make` should take care of that.'

write_to_macro_file '\def\nRealFaultsWithOnlyOneBuggyLine{'"$N_SINGLE_LINE_FAULTS"'\xspace}'
write_to_macro_file '\def\fractionOfRealFaultsWithOnlyOneBuggyLine{'$(expr 100 '*' $N_SINGLE_LINE_FAULTS / $N_FAULTS)'\%\xspace}'

write_to_macro_file '\def\nRealFaultsWithMultipleBuggyLines{'"$N_MULTILINE_FAULTS"'\xspace}'
write_to_macro_file '\def\fractionOfRealFaultsWithMultipleBuggyLines{'$(expr 100 '*' $N_MULTILINE_FAULTS / $N_FAULTS)'\%\xspace}'

write_to_macro_file '\def\nRealFaultsWithOmissions{'"$N_FAULTS_WITH_OMISSIONS"'\xspace}'
write_to_macro_file '\def\fractionOfRealFaultsWithOmissions{'$(expr 100 '*' $N_FAULTS_WITH_OMISSIONS / $N_FAULTS)'\%\xspace}'

write_to_macro_file '\def\nRealFaultsWithOnlyOmissions{'"$N_FAULTS_WITH_ONLY_OMISSIONS"'\xspace}'
write_to_macro_file '\def\fractionOfRealFaultsWithOnlyOmissions{'$(expr 100 '*' $N_FAULTS_WITH_ONLY_OMISSIONS / $N_FAULTS)'\%\xspace}'

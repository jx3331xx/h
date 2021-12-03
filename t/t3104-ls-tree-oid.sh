#!/bin/sh

test_description='git ls-tree oids handling.'

. ./test-lib.sh

test_expect_success 'setup' '
	echo 111 >1.txt &&
	echo 222 >2.txt &&
	mkdir -p path0/a/b/c &&
	echo 333 >path0/a/b/c/3.txt &&
	find *.txt path* \( -type f -o -type l \) -print |
	xargs git update-index --add &&
	tree=$(git write-tree) &&
	echo $tree
'

test_expect_success 'usage: --oid-only' '
	git ls-tree --oid-only $tree >current &&
	git ls-tree $tree | awk "{print \$3}" >expected &&
	test_cmp current expected
'

test_expect_success 'usage: --oid-only with -r' '
	git ls-tree --oid-only -r $tree >current &&
	git ls-tree -r $tree | awk "{print \$3}" >expected &&
	test_cmp current expected
'

test_expect_success 'usage: --oid-only with --abbrev' '
	git ls-tree --oid-only --abbrev=6 $tree >current &&
	git ls-tree --abbrev=6 $tree | awk "{print \$3}" > expected &&
	test_cmp current expected
'

test_expect_failure 'usage: incompatible options: --name-only with --oid-only' '
	test_incompatible_usage git ls-tree --oid-only --name-only
'

test_done

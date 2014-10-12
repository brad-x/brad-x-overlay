# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

USE_RUBY="ruby19 ruby20"

RUBY_FAKEGEM_TASK_TEST="spec"

inherit ruby-fakegem

DESCRIPTION="Indexer provides projects with a universal metadata format."
HOMEPAGE="https://rubygems.org/gems/indexer"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

ruby_add_bdepend "
	dev-ruby/ae
	dev-ruby/qed"

all_ruby_install() {
	all_fakegem_install
}


# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

USE_RUBY="ruby19 ruby20"

RUBY_FAKEGEM_TASK_TEST="spec"

inherit ruby-fakegem

DESCRIPTION="Turn provides a set of alternative runners for MiniTest, both colorful and informative."
HOMEPAGE="https://rubygems.org/gems/turn"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

ruby_add_bdepend "
	dev-ruby/detroit
	dev-ruby/qed"

all_ruby_install() {
	all_fakegem_install
}


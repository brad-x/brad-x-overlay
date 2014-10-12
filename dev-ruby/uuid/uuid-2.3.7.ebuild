# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

USE_RUBY="ruby19 ruby20"

RUBY_FAKEGEM_TASK_TEST="spec"

inherit ruby-fakegem

DESCRIPTION="UUID generator for producing universally unique identifiers based on RFC 4122 "
HOMEPAGE="https://rubygems.org/gems/uuid"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

ruby_add_rdepend "dev-ruby/macaddr"

ruby_add_bdepend "test? ( dev-ruby/rspec )"

all_ruby_install() {
	all_fakegem_install
	rm "${D}/usr/bin/rake"
}


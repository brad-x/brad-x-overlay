# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

USE_RUBY="ruby19 ruby20"

RUBY_FAKEGEM_TASK_TEST="spec"

inherit ruby-fakegem

DESCRIPTION="Windows Azure Client Library for Ruby"
HOMEPAGE="https://rubygems.org/gems/azure"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

ruby_add_rdepend "
	dev-ruby/json
	dev-ruby/mime-types
	dev-ruby/nokogiri
	dev-ruby/systemu
	dev-ruby/uuid"

ruby_add_bdepend "
	dev-ruby/rake
	dev-ruby/minitest
	dev-ruby/mocha
	dev-ruby/turn"

all_ruby_install() {
	all_fakegem_install
}


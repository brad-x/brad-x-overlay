# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

USE_RUBY="ruby19 ruby20"

RUBY_FAKEGEM_TASK_TEST="spec"

inherit ruby-fakegem

DESCRIPTION="The softlayer_api gem offers a convenient mechanism for invoking the services of the SoftLayer API from Ruby."
HOMEPAGE="https://rubygems.org/gems/softlayer_api"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

ruby_add_rdepend "
	dev-ruby/configparser"

ruby_add_bdepend "
	dev-ruby/rake
	dev-ruby/coveralls
	dev-ruby/json
	dev-ruby/rdoc
	dev-ruby/rspec"

all_ruby_install() {
	all_fakegem_install
}


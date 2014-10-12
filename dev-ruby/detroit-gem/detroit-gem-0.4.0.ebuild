# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

USE_RUBY="ruby19 ruby20"

RUBY_FAKEGEM_TASK_TEST="spec"

inherit ruby-fakegem

DESCRIPTION="Detroit is an advanced lifecycle build system. With Detroit, build tasks are user defined service instances tied to stops along a track. Whenever the detroit console command is run, a track is followed from beginning to designated destination."
HOMEPAGE="https://rubygems.org/gems/detroit"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

ruby_add_rdepend "
	dev-ruby/detroit-standard"

all_ruby_install() {
	all_fakegem_install
}


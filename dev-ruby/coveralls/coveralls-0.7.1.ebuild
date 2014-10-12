# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

USE_RUBY="ruby19 ruby20"

RUBY_FAKEGEM_TASK_TEST="spec"

inherit ruby-fakegem

DESCRIPTION="VCR provides a simple API to record and replay your test suite's HTTP interactions. It works with a variety of HTTP client libraries, HTTP stubbing libraries and testing frameworks."
HOMEPAGE="https://rubygems.org/gems/vcr"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

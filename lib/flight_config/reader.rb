#
# Copyright (c) 2019 Steve Norledge, Alces Flight
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#  * Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

require 'flight_config/core'
require 'ice_nine'

module FlightConfig
  module Reader
    include Core

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def protected_new(*a)
        new(*a).tap do |config|
          yield config if block_given?
          IceNine.deep_freeze(config.__data__)
        end
      end

      def allow_missing_read(fetch: false)
        if fetch
          @allow_missing_read ||= false
        else
          @allow_missing_read = true
        end
      end

      def read(*a)
        protected_new(*a) do |config|
          if File.exists?(config.path)
            Core.log(config, 'read')
            Core.read(config)
          elsif allow_missing_read(fetch: true)
            Core.log(config, 'read (missing)')
          else
            raise MissingFile, "The file does not exist: #{config.path}"
          end
        end
      end
      alias_method :load, :read
    end
  end
  Loader = Reader
end


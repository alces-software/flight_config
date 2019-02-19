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

require 'flight_config/exceptions'
require 'flight_config/reader'

module FlightConfig
  module Updater
    include Core

    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.create_or_update(config, action:)
      Core.log(config, action)
      Core.lock(config) do
        config.__data__
        yield config if block_given?
        Core.log(config, "#{action} (write)")
        Core.write(config)
      end
      Core.log(config, "#{action} (done)")
    end

    def self.create_error_if_exists(config)
      return unless File.exist?(config.path)
      raise CreateError, <<~ERROR.chomp
        Create failed! The config already exists: #{config.path}
      ERROR
    end

    def self.update_error_if_missing(config)
      return if File.exists?(config.path)
      raise MissingFile, <<~ERROR.chomp
        Update failed! The config does not exist: #{config.path}
      ERROR
    end

    module ClassMethods
      include Reader::ClassMethods

      def update(*a, &b)
        new!(*a) do |config|
          Updater.update_error_if_missing(config)
          config.__data__set_read_mode
          Updater.create_or_update(config, action: 'update', &b)
        end
      end

      def create_or_update(*a, &b)
        new!(*a) do |config|
          config.__data__set_read_mode if File.exists?(config.path)
          Updater.create_or_update(config, action: 'create_or_update', &b)
        end
      end

      def create(*a, &b)
        new!(*a) do |config|
          Updater.create_error_if_exists(config)
          Updater.create_or_update(config, action: 'create', &b)
        end
      end
    end
  end
end

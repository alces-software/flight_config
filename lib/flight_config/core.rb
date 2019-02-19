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
require 'flight_config/log'
require 'flight_config/patches/tty_config'
require 'timeout'

module FlightConfig
  module Core
    PLACEHOLDER = '__flight_config_placeholder__'

    def self.log(obj, action)
      Log.info "#{action}: #{obj.path}"
    end

    def self.read(obj)
      str = File.read(obj.path)
      data = (str == PLACEHOLDER ? nil : YAML.load(str))
      return unless data
      obj.__data__.merge(data)
    end

    def self.write(obj)
      FileUtils.mkdir_p(File.dirname(obj.path))
      obj.__data__.write(obj.path, force: true)
    end

    def self.lock(obj)
      placeholder = false
      io = nil
      unless File.exists?(obj.path)
        Core.log(obj, 'placeholder')
        placeholder = true
        FileUtils.mkdir_p(File.dirname(obj.path))
        File.write(obj.path, PLACEHOLDER)
      end
      begin
        io = File.open(obj.path, 'r+')
        Timeout.timeout(0.1) { io.flock(File::LOCK_EX) }
      rescue Timeout::Error
        raise ResourceBusy, "The following resource is busy: #{obj.path}"
      end
      yield if block_given?
    ensure
      io&.close
      if placeholder && File.read(obj.path) == PLACEHOLDER
        FileUtils.rm_f(obj.path)
        Core.log(obj, 'placeholder (removed)')
      end
    end

    attr_reader :__data__mode

    def __data__initialize(_tty_config)
    end

    def __data__read(tty_config)
      if File.exists?(path)
        yaml_h = YAML.load(File.read(path))
        return unless yaml_h
        tty_config.merge(yaml_h)
      else
        raise MissingFile, "The file does not exist: #{path}"
      end
    end

    def __data__set_read_mode
      # Do not call '__data__' directly as this skips the initialize block
      if @__data__
        raise BadModeError, <<~ERROR.chomp
          The read mode can not be changed after __data__ has been set
        ERROR
      else
        @__data__mode = :read
      end
    end

    def __data__
      @__data__ ||= TTY::Config.new.tap do |core|
        if __data__mode == :read
          raise NotImplementedError
        else
          __data__initialize(core)
        end
      end
    end

    def path
      raise NotImplementedError
    end
  end
end

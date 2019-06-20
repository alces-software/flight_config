#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of FlightConfig.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# FlightConfig is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with FlightConfig. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on FlightConfig, please visit:
# https://github.com/openflighthpc/flight_config
#==============================================================================
require 'flight_config/reader'

module FlightConfig
  module Globber
    class Matcher
      attr_reader :klass, :arity, :registry

      def initialize(klass, arity, registry)
        @klass = klass
        @arity = arity
        @registry = (registry || FlightConfig::Registry.new)
      end

      def keys
        @keys ||= Array.new(arity) { |i| "arg#{i}" }
      end

      def regex
        @regex ||= begin
          regex_inputs = keys.map { |k|  "(?<#{k}>.*)" }
          /#{klass.new(*regex_inputs).path}/
        end
      end

      def read(path)
        data = regex.match(path)
        init_args = keys.map { |key| data[key] }
        klass.read(*init_args, registry: registry)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def glob_read(*a, registry: nil)
        matcher = Globber::Matcher.new(self, a.length, registry)
        glob_regex = self.new(*a).path
        Dir.glob(glob_regex)
           .map { |path| matcher.read(path) }
      end
    end
  end
end


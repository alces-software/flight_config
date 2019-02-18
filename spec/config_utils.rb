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

RSpec.shared_context 'with config utils' do |*additional_includes|
  def self.with_existing_subject_file
    let!(:subject_file) do
      Tempfile.create(*temp_file_input).tap do |file|
        file.write(YAML.dump(initial_data_hash)) unless initial_subject_data.nil?
        file.flush
      end
    end
    let(:subject_path) { subject_file.path }

    after do
      begin
        File.unlink(subject_file)
      rescue Errno::ENOENT
        # :noop: The file has already been deleted
      end
    end
  end

  def self.with_missing_subject_file
    let(:subject_path) do
      file = Tempfile.new(*temp_file_input)
      path = file.path
      file.close
      file.unlink
      path
    end

    after { FileUtils.rm_f subject_path }
  end

  def self.it_loads_empty_subject_config
    it 'loads an empty hash equivalent TTY::Config object' do
      expect(subject.__data__).to be_a(TTY::Config)
      expect(subject.__data__.to_h).to be_empty
    end
  end

  def self.it_behaves_like_initial_subject_data_reader
    context 'with initial_subject_data' do
      let(:initial_subject_data) { { 'key' => 'value' } }

      it 'loads in the existing data' do
        expect(subject.__data__.fetch(:data)).to eq(initial_subject_data)
      end
    end
  end

  def self.it_locks_the_file(method)
    it 'runs the block in a file lock' do
      config_class.public_send(method, subject_path) do |config|
        File.open(config.path, 'r+') do |file|
          expect(file.flock(File::LOCK_EX|File::LOCK_NB)).to be_falsey
        end
      end
    end
  end

  def self.it_raises_missing_file
    it 'raises MissingFile' do
      expect { subject }.to raise_error(FlightConfig::MissingFile)
    end
  end

  let(:temp_file_input) { [['rspec_flight_config', '.yaml'], '/tmp'] }

  let(:config_class) do
    classes = [*additional_includes, described_class].flatten
    Class.new do
      classes.each { |c| include c }

      attr_reader :path

      def initialize(path)
        @path = path
      end

      def data=(input)
        __data__.set(:data, value: input)
      end

      def data
        __data__.fetch(:data)
      end
    end
  end

  let(:subject_path) do
    raise NotImplementedError
  end

  let(:initial_subject_data) { nil }

  let(:initial_data_hash) { { "data" => initial_subject_data } }
end

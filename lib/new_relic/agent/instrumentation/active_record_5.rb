# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.
require 'new_relic/agent/instrumentation/active_record_subscriber'

module NewRelic
  module Agent
    module Instrumentation
      module ActiveRecord
        ACTIVE_RECORD = "ActiveRecord".freeze

        module BaseExtensions
          def save(*args, &blk)
            ::NewRelic::Agent.with_database_metric_name(self.class.name, nil, ::NewRelic::Agent::Instrumentation::ActiveRecord::ACTIVE_RECORD) do
              super
            end
          end

          def save!(*args, &blk)
            ::NewRelic::Agent.with_database_metric_name(self.class.name, nil, ::NewRelic::Agent::Instrumentation::ActiveRecord::ACTIVE_RECORD) do
              super
            end
          end
        end

        module RelationExtensions
        end
      end
    end
  end
end

DependencyDetection.defer do
  named :active_record_5

  depends_on do
    defined?(::ActiveRecord) && defined?(::ActiveRecord::Base) &&
      defined?(::ActiveRecord::VERSION) &&
      ::ActiveRecord::VERSION::MAJOR.to_i == 5
  end

  depends_on do
    !NewRelic::Agent.config[:disable_activerecord_instrumentation] &&
      !NewRelic::Agent::Instrumentation::ActiveRecordSubscriber.subscribed?
  end

  executes do
    ::NewRelic::Agent.logger.info 'Installing ActiveRecord 5 instrumentation'
  end

  executes do
    ActiveSupport::Notifications.subscribe('sql.active_record',
      NewRelic::Agent::Instrumentation::ActiveRecordSubscriber.new)

    ActiveSupport.on_load(:active_record) do
      ::ActiveRecord::Base.prepend ::NewRelic::Agent::Instrumentation::ActiveRecord::BaseExtensions
      ::NewRelic::Agent::Instrumentation::ActiveRecordHelper.instrument_relation_methods
    end
  end
end

require 'kolekti/persistence_strategy'

module Kolekti
  class MemoryPersistenceStrategy < Kolekti::PersistenceStrategy
    attr_reader :tree_metric_results, :hotspot_metric_results, :related_hotspot_metric_results

    def initialize
      @tree_metric_results = []
      @hotspot_metric_results = []
      @related_hotspot_metric_results = []
    end

    def create_tree_metric_result(metric_configuration, module_name, value, granularity)
      unless metric_already_in_use?(module_name, metric_configuration)
        @tree_metric_results << {
          metric_configuration: metric_configuration,
          module_name: module_name,
          value: value,
          granularity: granularity
        }
      else
        raise AlreadyTakenModuleException.new(module_name, metric_configuration)
      end
    end

    def create_hotspot_metric_result(metric_configuration, module_name, line, message)
      result = {
        metric_configuration: metric_configuration,
        module_name: module_name,
        line: line,
        message: message
      }
      @hotspot_metric_results << result
      result
    end

    def create_related_hotspot_metric_results(metric_configuration, results)
      related_results = []

      results.each do |result|
        result = create_hotspot_metric_result(metric_configuration, result['module_name'], result['line'], result['message'])
        related_results << result
      end

      related_hotspot_metric_results << related_results
    end

    private

    def metric_already_in_use?(module_name, metric_configuration)
      @tree_metric_results.any? do |metric|
        has_same_name?(metric, module_name) and uses_same_configuration?(metric, metric_configuration)
      end
    end

    def has_same_name?(metric, module_name)
      metric[:module_name] == module_name
    end

    def uses_same_configuration?(metric, metric_configuration)
      metric[:metric_configuration] == metric_configuration
    end

  end

  class AlreadyTakenModuleException < Exception
    def initialize(module_name, metric)
      reason = "The module #{module_name} already has a result stored for the metric #{metric}"
      super(reason)
    end
  end

end

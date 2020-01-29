# frozen_string_literal: true

module Facter
  module El
    class NetworkingIp
      FACT_NAME = 'networking.ip'
      ALIASES = 'ipaddress'

      def call_the_resolver
        fact_value = Resolvers::NetworkingLinux.resolve(:ip)

        [ResolvedFact.new(FACT_NAME, fact_value), ResolvedFact.new(ALIASES, fact_value, :legacy)]
      end
    end
  end
end
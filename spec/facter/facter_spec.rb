# frozen_string_literal: true

describe 'facter' do
  before do
    RbConfig::CONFIG['host_os'] = 'linux'
    allow(OsReleaseResolver).to receive(:resolve).with(:identifier).and_return('Ubuntu')
    allow(OsReleaseResolver).to receive(:resolve).with(:version).and_return('18.04')
  end
  it 'returns one fact' do
    ubuntu_os_name = double(Facter::Ubuntu::OsName)
    loaded_facts = { 'os.name' => ubuntu_os_name }
    fact_name = 'os.name'
    fact_value = 'ubuntu'
    options = {}

    allow(CurrentOs.instance).to receive(:identifier).and_return('ubuntu')
    os_fact = double(Facter::ResolvedFact, name: fact_name, value: fact_value, user_query: '', filter_tokens: [])
    allow(os_fact).to receive(:value=).with('ubuntu')
    allow_any_instance_of(Facter::Ubuntu::OsName).to receive(:call_the_resolver).and_return(os_fact)

    allow_any_instance_of(Facter::FactLoader).to receive(:load_with_legacy).with(fact_value).and_return(loaded_facts)
    allow_any_instance_of(Facter::QueryParser).to receive(:parse).with([fact_name], loaded_facts)

    fact_hash = Facter::Base.new.resolve_facts(options, [fact_name])

    expected_resolved_fact_list = [os_fact]

    expect(fact_hash).to eq(expected_resolved_fact_list)
  end

  it 'returns one custom fact' do
    network_interface_class = Facter::Ubuntu::NetworkInterface
    networking_interface_mock = double(Facter::Ubuntu::NetworkInterface)
    loaded_facts = { 'ipaddress_.*_legacy' => network_interface_class }
    options = {}
    os_name = 'ubuntu'
    fact_name = 'ipaddress_.*_legacy'
    resolved_fact_name = 'ipaddress_ens160_legacy'
    user_query = 'ipaddress_ens160_legacy'
    fact_value = '127.0.0.1'

    allow(CurrentOs.instance)
      .to receive(:identifier)
      .and_return(os_name)

    allow(Facter::FactLoader)
      .to receive(:load_with_legacy)
      .with(os_name)
      .and_return(loaded_facts)

    allow_any_instance_of(Facter::QueryParser)
      .to receive(:parse)
      .with([user_query], loaded_facts)

    regex_resolved_fact =
      double(Facter::ResolvedFact, name: resolved_fact_name, value: fact_value, user_query: nil, filter_tokens: [])

    allow(regex_resolved_fact)
      .to receive(:value=)
      .with(fact_value)

    allow(regex_resolved_fact)
      .to receive(:name=)
      .with(fact_name)

    allow_any_instance_of(Facter::Ubuntu::NetworkInterface)
      .to receive(:new)
      .and_return(networking_interface_mock)

    allow_any_instance_of(Facter::Ubuntu::NetworkInterface)
      .to receive(:call_the_resolver)
      .and_return(regex_resolved_fact)

    allow(regex_resolved_fact)
      .to receive(:user_query=)

    allow(regex_resolved_fact)
      .to receive(:filter_tokens=)

    stub_const('Facter::Ubuntu::NetworkInterface', fact_name)
    resolved_fact_array = Facter::Base.new.resolve_facts(options, [user_query])

    expected_resolved_fact_list = [regex_resolved_fact]

    expect(resolved_fact_array).to eq(expected_resolved_fact_list)
  end

  it 'returns the value of the user query' do
    user_query = 'os.name'
    query_result = 'ubuntu'

    fact_base = double(Facter::Base)
    allow(Facter::Base).to receive(:new).and_return(fact_base)
    resolved_fact = double(Facter::ResolvedFact, name: 'os.name', value: 'Darwin', user_query: '', filter_tokens: [])
    resolved_fact_list = [resolved_fact]
    allow(fact_base).to receive(:resolve_facts).with({}, [user_query]).and_return(resolved_fact_list)

    fact_collection = double(Facter::FactCollection)
    allow(Facter::FactCollection).to receive(:new).and_return(fact_collection)
    allow(fact_collection).to receive(:build_fact_collection!).with(resolved_fact_list).and_return(fact_collection)
    allow(fact_collection).to receive(:dig).with('os', 'name').and_return(query_result)

    query_result = Facter.value(user_query)
    expect(query_result).to eq(query_result)
  end

  it 'return a hash with all resolved facts do' do
    fact_base = double(Facter::Base)
    allow(Facter::Base).to receive(:new).and_return(fact_base)

    resolved_fact1 =
      double(Facter::ResolvedFact, name: 'os.name', value: 'Darwin', user_query: '', filter_tokens: [])
    resolved_fact2 =
      double(Facter::ResolvedFact, name: 'os.hardware', value: 'x86_64', user_query: '', filter_tokens: [])

    resolved_fact_list = [resolved_fact1, resolved_fact2]
    allow(fact_base).to receive(:resolve_facts).and_return(resolved_fact_list)

    fact_collection = double(Facter::FactCollection)
    allow(Facter::FactCollection).to receive(:new).and_return(fact_collection)
    allow(fact_collection).to receive(:build_fact_collection!).with(resolved_fact_list).and_return(fact_collection)

    resolved_fact_collection = Facter.to_hash
    expect(resolved_fact_collection).to eq(fact_collection)
  end

  it 'returns user output' do
    options = {}
    user_query = ['os.name', 'os.hardware']

    fact_base = double(Facter::Base)
    allow(Facter::Base).to receive(:new).and_return(fact_base)

    resolved_fact1 =
      double(Facter::ResolvedFact, name: 'os.name', value: 'Darwin', user_query: '', filter_tokens: [])
    resolved_fact2 =
      double(Facter::ResolvedFact, name: 'os.hardware', value: 'x86_64', user_query: '', filter_tokens: [])

    resolved_fact_list = [resolved_fact1, resolved_fact2]
    allow(fact_base).to receive(:resolve_facts).with(options, user_query).and_return(resolved_fact_list)

    json_fact_formatter = double(Facter::JsonFactFormatter)
    allow(Facter::FormatterFactory).to receive(:build).with(options).and_return(json_fact_formatter)
    expect(json_fact_formatter).to receive(:format).and_return('json_formatter')

    user_output = Facter.to_user_output(options, *user_query)
    expect(user_output).to eq('json_formatter')
  end
end

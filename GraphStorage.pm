package GraphStorage;

use strict;
use warnings;

use REST::Neo4p;

  sub new {
        my $class       = shift;
        my $rot_machine = shift;

	eval {
		REST::Neo4p->connect('http://127.0.0.1:7474');
	};
	ref $@ ? $@->rethrow : die $@ if $@;

        my $self = bless {
                        node_index   => REST::Neo4p->get_index_by_name('user_names','node'),
			edge_index   => REST::Neo4p->get_index_by_name('user_rels', 'relationship') 
                   }, $class;
        return  $self;
  }

  # Сохраняет новый узел без атрибутов. На входе id узла
  sub save_node
  {
	my $self     = shift;
	my $nodeid   = shift;

	my $node     = REST::Neo4p::Node->new({ id => $nodeid });

	$self->{node_index}->add_entry( $node );
  }

  # Проверяет существование оконечных узлов, и сохраняет ребро методом создания нужных оконечных узлов и связи между ними ( если узлы ещё не были созданы ). Т.е. если сохраняем ребро A -> B, и B уже есть, то создаётся A и свящь от A к B
  # Если оба узла уже есть, не делаем ничего ( чтобы добавить новую связь, нужно пользоваться методом relate_node )
  sub save_edge
  {
	my $self     = shift;
	my ( $source_id, $target_id ) = shift;

	my $src        = $self->{node_index}->find_entries( 'id' => $source_id );
	my $dst        = $self->{node_index}->find_entries( 'id' => $source_id );

	my ( $new_src, $new_trg );
	if ( ! $src )
	{
		$new_src   = REST::Neo4p::Node->new({ id => $source_id});
		$self->{node_index}->add_entry( $new_src );
	}

	if ( ! $dst )
	{
		my $new_trg   = REST::Neo4p::Node->new({ id => $target_id});
		$self->{node_index}->add_entry( $new_trg );
	}

	my $node_trg   = ( ! defined $dst ) ? $new_trg : $dst;
	my $node_src   = ( ! defined $src ) ? $new_src : $src;

	my $my_rel     = $node_trg->relate_to( $node_src, 'follower');	

	$self->{edge_index}->add_entry( $my_rel );
  }

  # Принимает хэшик с действиями 'add', 'delete', 'modify'. Атрибуты узла, перечисленные в соотв. разделе, соотв., добавляются, удаляются или заменяются на указанные 
  sub modify_node
  {

  }

  # Добавляет связь между двумя указанными узлами ( УЖЕ существующими, узлы получаются методом get*by_id. На входе -- айдишники узлов.
  sub relate_node
  {
	my $self   	          = shift;
	my ( $source, $target )   = shift;
  }

  # Возвращает структуру, соответствующую узлу, по его айдишнику
  sub query_node
  {
	my $self    = shift;
	my $nodeid  = shift;

	my $idx     = $self->{node_index}; 
	my @nodes   = $idx->find_entries( id => "$nodeid");

	return @nodes;
  }

1;

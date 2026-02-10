-module(gb_trees_shim).

-export([lookup_shim/2, smaller_shim/2, larger_shim/2, next_shim/1]).

lookup_shim(Tree, Key) ->
    case gb_trees:lookup(Key, Tree) of
        none ->
            {error, nil};
        {value, Value} ->
            {ok, Value}
    end.

smaller_shim(Tree, Key) ->
    case gb_trees:smaller(Key, Tree) of
        none ->
            {error, nil};
        Tuple ->
            {ok, Tuple}
    end.

larger_shim(Tree, Key) ->
    case gb_trees:larger(Key, Tree) of
        none ->
            {error, nil};
        Tuple ->
            {ok, Tuple}
    end.

next_shim(Iter1) ->
    case gb_trees:next(Iter1) of
        none ->
            {error, nil};
        Tuple ->
            {ok, Tuple}
    end.

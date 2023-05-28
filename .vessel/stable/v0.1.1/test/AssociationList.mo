import Text "mo:base-0.7.3/Text";

import AL "../src/AssociationList";
import LL "../src/LinkedList";

do {
    var l : AL.AssociationList<Text, Nat> = LL.fromArray(
        [ ("a", 0)
        , ("b", 1)
        , ("c", 2)
        ],
    );
    let equal = Text.equal;

    func update((l_, ov) : (AL.AssociationList<Text, Nat>, ?Nat)) : ?Nat {
        l := l_; ov;
    };

    assert(AL.get(l, "a", equal) == ?0);
    assert(LL.size(l) == 3);
    assert(update(AL.delete(l, "a", equal)) == ?0);
    assert(LL.size(l) == 2);
    assert(update(AL.delete(l, "a", equal)) == null);
    assert(LL.size(l) == 2);
    assert(update(AL.insert(l, "a", equal, 0)) == null);
    assert(LL.size(l) == 3);
};
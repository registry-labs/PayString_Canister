import Iter "mo:base-0.7.3/Iter";
import Text "mo:base-0.7.3/Text";

import HM "../src/HashMap";
import SHM "../src/Stable/HashMap";

do {
    var m     = HM.empty<Text, Nat>();
    let hash  = Text.hash;
    let equal = Text.equal;

    func update((m_, ov) : (HM.HashMap<Text, Nat>, ?Nat)) : ?Nat {
        m := m_; ov;
    };

    assert(update(HM.insert(m, "a", hash, equal, 0)) == null);
    assert(update(HM.remove(m, "a", hash, equal)) == ?0);
    assert(update(HM.insert(m, "a", hash, equal, 0)) == null);
    assert(update(HM.insert(m, "a", hash, equal, 0)) == ?0);
    assert(HM.size(m) == 1);
    assert(HM.get(m, "a", hash, equal) == ?0);

    assert(update(HM.insert(m, "b", hash, equal, 1)) == null);
    assert(update(HM.insert(m, "c", hash, equal, 2)) == null);
    assert(HM.size(m) == 3);

    assert(Iter.toArray(HM.entries(m)).size() == 3);
    for ((k, v) in HM.entries(m)) {
        switch (HM.get(m, k, hash, equal)) {
            case (null) { assert(false);   };
            case (? v_) { assert(v == v_); };
        };
    };

    switch (HM.get(m, "d", hash, equal)) {
        case (? v)  { assert(false); };
        case (null) {};
    };

    switch (update(HM.insert(m, "a", hash, equal, 10))) {
        case (null) { assert(false); };
        case (? v)  {
            assert(v == 0);
            assert(update(HM.insert(m, "a", hash, equal, 1)) == ?10);
        };
    };

    let s = switch (SHM.fromStable(m, hash, equal)) {
        case (#ok(s))  { s; };
        case (#err(v)) {
            assert(false);
            SHM.HashMap<Text, Nat>(hash, equal);
        };
    };
    assert(HM.size(m) == s.size());
    for ((k, v) in s.entries()) {
        switch (HM.get(m, k, hash, equal)) {
            case (null) { assert(false);   };
            case (? v_) { assert(v == v_); };
        };
    };
};

let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.21-20220215/package-set.dhall sha256:b46f30e811fe5085741be01e126629c2a55d4c3d6ebf49408fb3b4a98e37589b  
let aviate-labs = https://github.com/aviate-labs/package-set/releases/download/v0.1.8/package-set.dhall sha256:9ab42c1f732299dc8c1f631d39ea6a2551414bf6efc8bbde4e11e36ebc6d7edd
let packages = [
  { name = "stable-rbtree"
  , repo = "https://github.com/canscale/StableRBTree"
  , version = "v0.6.0"
  , dependencies = [ "base" ]
  },
  { name = "stable-buffer"
  , repo = "https://github.com/canscale/StableBuffer"
  , version = "v0.2.0"
  , dependencies = [ "base" ]
  },
  { name = "crypto"
  , repo = "https://github.com/aviate-labs/crypto.mo"
  , version = "v0.3.0"
  , dependencies = [ "base", "encoding" ]
  },
  { name = "hash"
  , repo = "https://github.com/aviate-labs/hash.mo"
  , version = "v0.1.0"
  , dependencies = [ "array", "base" ]
  },
  { name = "rand"
  , repo = "https://github.com/aviate-labs/rand.mo"
  , version = "v0.2.2"
  , dependencies = [ "base", "encoding", "io" ]
  },
  { name = "ulid"
  , repo = "https://github.com/aviate-labs/ulid.mo"
  , version = "v0.1.2"
  , dependencies = [ "base", "encoding", "io" ]
  },
  { name = "uuid"
  , repo = "https://github.com/aviate-labs/uuid.mo"
  , version = "v0.2.1"
  , dependencies = [ "base", "encoding", "io" ]
  },
  { name = "base"
  , repo = "https://github.com/dfinity/motoko-base"
  , version = "7522808e315cd89e70096488728c24bec09576af" -- Motoko 0.7.6
  , dependencies = [] : List Text
  },
  { name = "json"
  , repo = "https://github.com/aviate-labs/json.mo"
  , version = "v0.2.1"
  , dependencies = [ "base-0.7.3", "parser-combinators" ]
  },
  { name = "stable"
  , repo = "https://github.com/aviate-labs/stable.mo"
  , version = "v0.1.1"
  , dependencies = [ "base-0.7.3" ]
  },
  { name = "http-parser"
  , repo = "https://github.com/NatLabs/http-parser.mo"
  , version = "v0.1.2"
  , dependencies = [ "base", "base-0.7.3", "json", "array", "encoding", "parser-combinators" ]
  }
]

in  upstream # aviate-labs # packages

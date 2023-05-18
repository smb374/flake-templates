{
  outputs = { self }: {
    templates.rust-binary = {
      path = ./rust/binary;
      description = "A simple Rust binary project.";
    };
    templates.rust-binary-nodevenv = {
      path = ./rust-nodevenv/binary;
      description = "A simple Rust binary project.";
    };
    templates.rust-lib-nodevenv = {
      path = ./rust-nodevenv/library;
      description = "A simple Rust library project.";
    };

    templates.default = self.templates.rust-binary;
  };
}

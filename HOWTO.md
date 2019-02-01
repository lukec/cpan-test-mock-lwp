# HOWTO use Test::Mock::LWP

`Test::Mock::LWP` is designed to provide you a quick way to mock out LWP calls.

## Exported variables

`Test::Mock::LWP`'s interface is exposed via the _variables_ it exports:

 - `$Mock_ua` - mocks `LWP::USerAgent`
 - `$Mock_req` / $Mock_request - mocks `HTTP::Request`
 - $Mock_resp / $Mock_response - mocks `HTTP::Response`
 
All of these are actually `Test::MockObject` objects, so you call `mock()`
on them to change how they operate dynamically. Here's an example.
 
Let's say you wanted the next response to an LWP call to return the content
`foo` and an HTTP status code of `201`. You'd do this:
 
	BEGIN {
		# Load the mock modules *first*.
	    use Test::Mock::LWP::UserAgent;
	    use Test::Mock::HTTP::Response;
	    use Test::Mock::HTTP::Request;
	}
	
	# Load the modules you'll use to actually do LWP operations.
	# These will automatically be mocked for you.
	use LWP::UserAgent;
	use HTTP::Response;
	use HTTP::Request;
    
	# Now set up the response you want to get back.
    $Mock_resp->mock( content => sub { 'foo' });
	$Mock_resp->mock( code    => sub { 201 });
	
	# Pretend we're making a request to a site.
	for (1..2) {
	  my $req   = HTTP::Request->new(GET => 'http://nevergoeshere.com');
	  my $agent = LWP::UserAgent->new;
	  my $res   = $agent->simple_request($req);
	}
	# The values you added to the mock are now there.
	printf("The site returned %d %s\n", $res->code, $res->content);

This will print

    201 foo
	201 foo

Note that the values are constrained to what you've sent to the mocks. The
mock here will simply keep returning `201` and `foo` for as many times as
you call it. You'll need to re-mock the `content` and `code` methods
each time you want to change them.

	my $req   = HTTP::Request->new(GET => 'http://nevergoeshere.com');
	my $agent = LWP::UserAgent->new;
	
    $Mock_resp->mock( content => sub { 'foo' });
	$Mock_resp->mock( code    => sub { 201 });
	my $res   = $agent->simple_request($req);
	printf("The site returned %d %s\n", $res->code, $res->content);
	# 201 foo
		
    $Mock_resp->mock( content => sub { 'bar' });
	$Mock_resp->mock( code    => sub { 400 });
	my $res   = $agent->simple_request($req);
	printf("The site returned %d %s\n", $res->code, $res->content);
    # 400 bar	

If you have a fixed sequence of items to return, just add them all to
the mocks and have the mocks step through them. Here's an example where
we hand off two lists of values to the mocks:

	my $req   = HTTP::Request->new(GET => 'http://nevergoeshere.com');
	my $agent = LWP::UserAgent->new;
	
	my($_agent, $_content, $_code) = sub {
	  my @contents = qw(foo bar baz);
	  my @codes    = wq(404 400 200);
	  my $counter = (scalar @contents) - 1;
	  
	  my $agent_sub   = sub {
	    $counter++;
		$counter %= scalar @contents;
	  };
	  
	  my $content_sub = sub {
		  $contents{$counter};
	  };
	  
	  my $code_sub = sub {
		  $codes{$counter};
	  };
	  return ($agent_sub, $content_sub, $code_sub);
	}->();
	
	$Mock_resp->mock(content => $_content);
	$Mock_resp->mock(code    => $_code);
	$Mock_ua->mock(simple_request => $_agent);
    
	for (0..5) {
      my $res   = $agent->simple_request($req);
	  printf("The site returned %d %s\n", $res->code, $res->content);
	} 


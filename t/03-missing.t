#!perl -T

use Test::More tests => 5;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new();

{#2
    my @res = $des->missing({ file =>  't/sample.data', search => 'this' });
    ok ( $res[0] =~ '\w+', "obj->missing() returns an array if file exists and text available" );
}
{#3
    my @res = $des->missing({ file => 't/sample.data', search => '' });
    ok ( ! @res, "obj->missing() returns an empty array if file exists and text is empty string" );
}
{#4
    my @res = $des->missing({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( @res, "obj->missing() returns an array if file exists and search text not found" );
}
{#5
    my $res = $des->missing({ file => 't/sample.data', search => 'this' });
    ok ( ref \$res eq 'SCALAR', "obj->missing() returns a scalar when called in scalar context" );
}


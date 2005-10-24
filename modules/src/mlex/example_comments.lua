s = [[ <a><!-- ciccia --></a> ]]
e = [[.*<a>.*<ciccia>.*</a>]]
g = [[X<X>X<X>X<X>]]
x = mlex.match(s,e,g)
x:print()
print [[{' ','a','','!-- ciccia --','','/a'}]]

s = [[ <a><script><!-- >> ciccia << --></script></a>]]
e = [[.*<a>.*<script>ciccia</script>.*</a>]]
g = [[X<X>X<X>X<X>X<X>]]
x = mlex.match(s,e,g)
x:print()
print [[{' ','a','','script','<!-- >> ciccia << -->','/script','','/a'}]]

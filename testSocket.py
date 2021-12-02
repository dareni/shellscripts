#python socket example
#server
import socket; s = socket.socket(socket.AF_INET, socket.SOCK_STREAM);
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('localhost', 9999))
s.listen()
conn,addr = s.accept()
conn.recv(1024)
conn.sendall(b'bye')
conn.shutdown(socket.SHUT_RDWR)
conn.close()


#client
import socket; s = socket.socket(socket.AF_INET, socket.SOCK_STREAM);
s.connect(('localhost', 9999))
s.sendall(b'hello')
s.recv(1024)
s.shutdown(socket.SHUT_RDWR)
s.close()



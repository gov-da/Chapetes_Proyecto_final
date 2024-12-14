-- ------------------------------- --
--		Realizar un pedido		   --
-- ------------------------------- --
-- Autor: Daniel Gómez Villaseñor
-- Fecha: 14/12/2024

/*
1. Agregar a carrito
	1.1. Comprobar que el cliente exista
	1.2. Comprobar que el producto exista
	1.3. Comprobar el estado del producto
	1.4. Comprobar que hay stock suficiente del producto
	1.5. Alterar el stock del producto
	1.6. Insertar producto a carrito

2. Generar la orden
	2.1. Comprobar que el cliente exista
	2.2. Comprobar que el empleado exista
	2.3. Generar la orden
	2.4. Generar los detalles y eliminarlos del carrito
*/


-- Tabla carrito
create table carrito(
	id_carrito int identity(1, 1),
	id_producto int not null,
	id_cliente varchar(5) not null,
	cantidad int not null,
	precio_unitario float,
	subtotal float,
	primary key(id_carrito)
);


-- Comprobar que el cliente exista
create function ComprobarCliente(
	@_id_cliente int
)
returns bit
as
begin
	declare
		@_ban bit;
	if exists(select 1 from clientes where id_cliente = @_id_cliente)
	begin
		set @_ban = 1;
	end
	else
	begin
		set @_ban = 0;
	end
	return @_ban;
end;

SELECT dbo.ComprobarCliente(1) AS ClienteExiste;

-- Comprobar tipo de orden
create function ComprobarTipo(
	@_id_tipo_orden int
)
returns bit
as
begin
	declare
		@_ban bit;
	if exists(select 1 from tipo_ordenes where id_tipo_orden = @_id_tipo_orden)
	begin
		set @_ban = 1;
	end
	else
	begin
		set @_ban = 0;
	end
	return @_ban;
end;

SELECT dbo.ComprobarTipo(3) AS TipoExiste;

-- Comprobar que el empleado exista
create function ComprobarEmpleado(
	@_id_empleado int
)
returns bit
as
begin
	declare
		@_ban bit;
	if exists(select 1 from empleados where id_empleado = @_id_empleado)
	begin
		set @_ban = 1;
	end
	else
	begin
		set @_ban = 0;
	end
	return @_ban;
end;

SELECT dbo.ComprobarEmpleado(1) AS EmpleadoExiste;


-- Comprobar que el producto exista
create function ComprobarProducto(
	@_id_producto int
)
returns bit
as
begin
	declare
		@_ban bit;
	if exists(select 1 from productos where id_producto = @_id_producto)
	begin
		set @_ban = 1;
	end
	else
	begin
		set @_ban = 0;
	end
	return @_ban;
end;

SELECT dbo.ComprobarProducto(1) AS ProductoExiste;


-- Comprobar el estado del producto
create function ComprobarEstado(
	@_id_producto int
)
returns bit
as
begin
	declare
		@_ban bit;
	if exists(select 1 from productos where id_producto = @_id_producto and id_disponibilidad = 1)
	begin
		set @_ban = 1;
	end
	else
	begin
		set @_ban = 0;
	end
	return @_ban;
end;

SELECT dbo.ComprobarEstado(1) AS ProductoDisponible;


-- Comprobar que hay stock suficiente del producto
create function ComprobarStock(
	@_id_producto int,
	@_cantidad int
)
returns bit
as
begin
	declare
		@_ban bit;
	if exists(select 1 from productos where id_producto = @_id_producto and @_cantidad <= cantidad_existencia)
	begin
		set @_ban = 1;
	end
	else
	begin
		set @_ban = 0;
	end
	return @_ban;
end;

SELECT dbo.ComprobarStock(1, 201) AS StockExiste;


-- Alterar el stock del producto
create procedure AlterarStock(
	@_id_producto int,
	@_cantidad int
)
as
begin
	declare
		@_cantidadComparar int,
		@_ban bit;
	select @_cantidadComparar= cantidad_existencia from productos where id_producto = @_id_producto;
	if @_cantidad <= @_cantidadComparar 
	begin
		update productos set cantidad_existencia = cantidad_existencia - @_cantidad where id_producto = @_id_producto;
		if @_cantidad = @_cantidadComparar
		begin
			update productos set id_disponibilidad = 2 where id_producto = @_id_producto;
		end
		set @_ban = 1;
	end
	else
	begin
		set @_ban = 0;
	end
	select @_ban;
end;

exec AlterarStock 2, 45


-- Comprobar que no sea un producto repetido
create function ProductoRepetido(
	@_id_cliente int,
	@_id_producto int
)
returns bit
as
begin
	declare
		@_ban bit;
	if exists(select 1 from carrito where id_cliente = @_id_cliente and id_producto = @_id_producto)
	begin
		set @_ban = 1;
	end
	else
	begin
		set @_ban = 0;
	end
	return @_ban;
end;


-- Agregar producto a la tabla carrito
create procedure InsertarProducto(
	@_id_producto int,
	@_id_cliente int,
	@_cantidad int
)
as
begin
	declare
		@_precio_unitario float,
		@_subtotal float,
		@_ban bit

		select @_precio_unitario = precio from productos where id_producto = @_id_producto;
		set @_ban = dbo.ProductoRepetido(@_id_cliente, @_id_producto);
		if @_ban = 0
		begin
			set @_subtotal = @_precio_unitario * @_cantidad;
			insert into carrito values (@_id_producto, @_id_cliente, @_cantidad, @_precio_unitario, @_subtotal)
		end
		else
		begin
			update carrito set cantidad = cantidad + @_cantidad where id_cliente = @_id_cliente and id_producto = @_id_producto
			select @_cantidad = cantidad from carrito where id_cliente = @_id_cliente and id_producto = @_id_producto;
			set @_subtotal = @_precio_unitario * @_cantidad;
			update carrito set subtotal = @_subtotal where id_cliente = @_id_cliente and id_producto = @_id_producto
		end
end;

exec InsertarProducto 6, 2, 1


-- Generar los detalles
create procedure GenerarDetalles(
	@_id_orden int,
	@_id_cliente int
)
as
begin
	insert into detalle_ordenes 
		select @_id_orden, id_producto, cantidad, precio_unitario from carrito where id_cliente = @_id_cliente
	delete from carrito where id_cliente = @_id_cliente
end;

exec GenerarDetalles 11, 1

select * from detalle_ordenes where id_orden = 13
select * from carrito
select * from ordenes


-- Resolución de la problemática
-- 1. Agregar a carrito
create procedure AgregarCarrito(
	@_id_producto int,
	@_id_cliente int,
	@_cantidad int
)
as
begin
	declare
		@_precio_unitario float,
		@_subtotal float,
		@_ban bit

		set @_ban = dbo.ComprobarCliente(@_id_cliente);
		if @_ban = 1
		begin

			set @_ban = dbo.ComprobarProducto(@_id_producto);
			if @_ban = 1
			begin
				
				set @_ban = dbo.ComprobarEstado(@_id_producto);
				if @_ban = 1
				begin
					
					set @_ban = dbo.ComprobarStock(@_id_producto, @_cantidad);
					if @_ban = 1
					begin

						exec dbo.AlterarStock @_id_producto, @_cantidad
						exec dbo.InsertarProducto @_id_producto, @_id_cliente, @_cantidad
					
					end
					else
					begin
						print 'No hay suficiente stock'
					end

				end
				else
				begin
					print 'El producto está agotado'
				end

			end
			else
			begin
				print 'El producto no existe'
			end

		end
		else
		begin
			print 'El cliente no existe'
		end
end;

exec dbo.AgregarCarrito 7, 3, 3


-- 2. Generar la orden
create procedure CrearOrden(
	@_id_cliente int,
	@_id_tipo_orden int,
	@_id_empleado int
)
as
begin
	declare 
		@_ban bit,
		@_id_orden int

	set @_ban = dbo.ComprobarCliente(@_id_cliente)
	if @_ban = 1
	begin

		set @_ban = dbo.ComprobarTipo(@_id_tipo_orden)
		if @_ban = 1
		begin

			set @_ban = dbo.ComprobarEmpleado(@_id_empleado)
			if @_ban = 1
			begin

				insert into ordenes values (@_id_cliente, @_id_tipo_orden, @_id_empleado, getdate(), 1)
				set @_id_orden = (select max(id_orden) from ordenes)
				exec dbo.GenerarDetalles @_id_orden, @_id_cliente
			
			end
			else
			begin
				print 'El empleado no existe';
			end

		end
		else
		begin
			print 'El tipo de orden no existe';
		end

	end
	else
	begin
		print 'El cliente no existe';
	end
end;

exec CrearOrden 7, 1, 2

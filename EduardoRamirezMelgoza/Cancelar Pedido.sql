-- ------------------------------- --
--		Cancelar un pedido		   --
-- ------------------------------- --
-- Autor: Eduardo Ramirez Melgoza
-- Fecha: 14/12/2024

--Verificar si la orden existe: Se consulta si la orden con el ID proporcionado existe en la tabla ordenes.
--Verificar el estado de la orden: Comprobar que la orden no esté ya cancelada o en un estado que impida su cancelación.
--Actualizar el estado de la orden a "cancelada": Si las condiciones anteriores se cumplen, se actualiza el estado de la orden a cancelada.
--Restaurar el inventario: Se regresan las cantidades de los productos al inventario.
--Revertir cambios en caso de error:


create   procedure Cancelar_pedido 
    @id_orden int
as
begin
    if exists (select 1 from ordenes where id_orden = @id_orden)
    begin
        declare @estado_orden int;
        select @estado_orden = id_estado from ordenes where id_orden = @id_orden;
        
        if @estado_orden != 2
        begin
            print 'La orden no se puede cancelar';
            return;
        end
        
        update ordenes
        set id_estado = 6 
        where id_orden = @id_orden;
        
        declare @id_producto int, @cantidad int;

        declare product_cursor cursor for 
            select id_producto, cantidad
            from detalle_ordenes_productos
            where id_orden = @id_orden;

        open product_cursor;
        fetch next from product_cursor into @id_producto, @cantidad;

        while @@fetch_status = 0
        begin
            update productos
            set cantidad = cantidad + @cantidad
            where id_producto = @id_producto;
            fetch next from product_cursor into @id_producto, @cantidad;
        end

        close product_cursor;
        deallocate product_cursor;

        print 'Pedido cancelado exitosamente';
    end
    else
    begin
        print 'La orden no existe';
    end
end



--7,8 Productos 1= 200  + 2, 2 = 50 + 4

begin transaction
EXEC cancelar_pedido 13;
select * from detalle_ordenes_productos;
select * from productos;
select * from ordenes;
commit 

select * from estados;


INSERT INTO ordenes (id_cliente, id_empleado, fecha, id_estado) VALUES
(1, 1, '2024-10-01', 2),
(2, 1, '2024-10-01', 2),
(3, 1, '2024-10-01', 2),
(4, 1, '2024-10-01', 2),
(5, 1, '2024-10-01', 2);

INSERT INTO detalle_ordenes_productos (id_orden, id_producto, cantidad, precio) VALUES
(13, 1, 2, 15.00),
(13, 2, 4, 15.00);




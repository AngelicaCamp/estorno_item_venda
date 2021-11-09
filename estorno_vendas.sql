CREATE OR REPLACE FUNCTION estornar_item_venda (p_id_venda INTEGER, p_id_produto INTEGER, p_qtde_estorno INTEGER) RETURNS INTEGER AS $$

	DECLARE v_qtde_produto INTEGER;
	DECLARE v_preco NUMERIC;
	DECLARE v_total NUMERIC;

BEGIN
	-- consultar qtde de itens inserido na venda
	
	 SELECT qtde INTO v_qtde_produto  
	 FROM item_venda 
	 WHERE id_venda = p_id_venda;
	 
	-- ESTORNO É TOTAL?
	
	IF (p_qtde_estorno = v_qtde_produto ) THEN
		-- Devolver ao estoque 
		 UPDATE produto 
		 SET qt_estoque = qt_estoque + p_qtde_estorno 
		 WHERE id = p_id_produto; 
		
		-- excluir da tabela item de venda
		DELETE FROM item_venda
		WHERE id_venda = p_id_venda;
				
		 -- excluir da tabela venda
		 DELETE FROM venda
		 WHERE id = p_id_venda;
		 
	-- ESTORNO É PARCIAL?
	
	ELSIF (p_qtde_estorno < v_qtde_produto ) THEN 
		-- Devolver ao estoque 
		 UPDATE produto 
		 SET qt_estoque = qt_estoque + p_qtde_estorno 
		 WHERE id = p_id_produto; 
		 
	    -- atualizar tabela item de venda (qtde e subtotal)
		
		 SELECT preco INTO v_preco       				-- consultar preço na tabela              
		 FROM item_venda 
		 WHERE id_venda = p_id_venda;
		 		 
		 UPDATE item_venda  							
		 SET qtde = v_qtde_produto - p_qtde_estorno
		 WHERE id_venda = p_id_venda;	
		 
		 UPDATE item_venda  							
		 SET subtotal = (v_qtde_produto - p_qtde_estorno) * v_preco
		 WHERE id_venda = p_id_venda;
		 		
		 
		 -- atualizar tabela venda (total)
		 
		 SELECT SUM(subtotal) INTO v_total 
		 FROM item_venda 
		 WHERE id_venda = p_id_venda;
		 
		 UPDATE venda 
		 SET total = v_total 
		 WHERE id = p_id_venda;	
	 			
	ELSE 
		RAISE NOTICE 'Transação não pode ser concluida : quantidade informada é superior ao permitido';
	END IF;
	
	RETURN 1;
	
END;
$$ LANGUAGE plpgsql;

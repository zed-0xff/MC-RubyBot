package net.fabricmc.example.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;
import org.spongepowered.asm.mixin.gen.Invoker;

import net.minecraft.client.render.entity.EntityRenderDispatcher;
import net.minecraft.entity.Entity;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.client.render.VertexConsumerProvider;
import net.minecraft.client.render.VertexConsumer;
import net.minecraft.client.render.TexturedRenderLayers;

@Mixin(EntityRenderDispatcher.class)
public interface EntityRenderDispatcherAccessor{
    @Invoker
    void invokeRenderHitbox(MatrixStack matrices, VertexConsumer vertices, Entity entity, float tickDelta);
}

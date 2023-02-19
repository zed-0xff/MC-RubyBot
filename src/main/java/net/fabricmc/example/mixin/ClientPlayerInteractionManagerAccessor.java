package net.fabricmc.example.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;
import org.spongepowered.asm.mixin.gen.Invoker;

import net.minecraft.client.network.ClientPlayerInteractionManager;
import net.minecraft.client.world.ClientWorld;
import net.minecraft.client.network.SequencedPacketCreator;

@Mixin(ClientPlayerInteractionManager.class)
public interface ClientPlayerInteractionManagerAccessor {
    @Accessor
    void setBreakingBlock(boolean b);

    @Invoker
    void invokeSyncSelectedSlot();

    @Invoker
    void invokeSendSequencedPacket(ClientWorld world, SequencedPacketCreator packetCreator);
}

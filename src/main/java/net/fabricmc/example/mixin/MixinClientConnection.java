package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;

import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.ModifyVariable;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.network.ClientConnection;
import net.minecraft.network.Packet;
import net.minecraft.network.listener.PacketListener;
import net.minecraft.network.NetworkState;
import net.minecraft.network.PacketCallbacks;

import net.minecraft.network.packet.c2s.play.PlayerInteractBlockC2SPacket;
import net.minecraft.network.packet.c2s.play.ClickSlotC2SPacket;
import net.minecraft.item.ItemStack;
import net.minecraft.client.MinecraftClient;

import net.minecraft.client.gui.screen.ingame.HandledScreen;

import net.minecraft.nbt.NbtCompound;

import net.minecraft.block.BlockState;
import net.minecraft.block.Blocks;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.hit.BlockHitResult;

@Mixin(ClientConnection.class)
public class MixinClientConnection {

	@Inject(
        method = "sendInternal(Lnet/minecraft/network/Packet;Lnet/minecraft/network/PacketCallbacks;Lnet/minecraft/network/NetworkState;Lnet/minecraft/network/NetworkState;)V",
        at = @At("HEAD"),
        cancellable = true
    )
	private void sendPacket(
            Packet<?> packet,
            PacketCallbacks callbacks,
            NetworkState packetState,
            NetworkState currentState,
            CallbackInfo ci)
    {
        if ( packet instanceof PlayerInteractBlockC2SPacket ){
            // prevent sending PlayerInteractBlockC2SPacket if current tool is 'magick stick' :D
            MinecraftClient mc = MinecraftClient.getInstance();
            int slot_id = mc.player.getInventory().selectedSlot;
            ItemStack stack = mc.player.getInventory().getStack(slot_id);
            if ( stack != null && stack.getItem() == net.minecraft.item.Items.STICK ){
                ci.cancel();
            } else {
                PlayerInteractBlockC2SPacket pkt = (PlayerInteractBlockC2SPacket) packet;
                BlockHitResult bh = pkt.getBlockHitResult();
                if ( bh != null ) {
                    BlockPos pos = bh.getBlockPos();
                    BlockState state = mc.world.getBlockState(pos);
                    if (state.getBlock() == Blocks.COBWEB) {
                        ci.cancel();
                    }
                }
            }
        }
	}

    @ModifyVariable(
        method = "sendInternal(Lnet/minecraft/network/Packet;Lnet/minecraft/network/PacketCallbacks;Lnet/minecraft/network/NetworkState;Lnet/minecraft/network/NetworkState;)V",
        at = @At("HEAD")
    )
    private Packet<?> modifyPacket(Packet<?> packet) {
        while ( packet instanceof ClickSlotC2SPacket ) {
            // send original slot_id if we had moved it to a different local slot
            // couldn't modify it in ScreenHandler.onSlotClick() I dunno why..
            ClickSlotC2SPacket pkt = (ClickSlotC2SPacket)packet;

            MinecraftClient mc = MinecraftClient.getInstance();
            if ( mc.currentScreen instanceof HandledScreen ) {
                //HandledScreen screen = (HandledScreen) mc.currentScreen;
                //screen.getScreenHandler()
                ItemStack stack = pkt.getStack();
                if ( stack == null ) break;

                NbtCompound nbt = stack.getNbt();
                if ( nbt == null ) break;

                int origSlot = nbt.getInt("origSlot");
                if ( origSlot == 0 ) break;

                packet = new ClickSlotC2SPacket(
                        pkt.getSyncId(),
                        pkt.getRevision(),
                        origSlot,
                        pkt.getButton(),
                        pkt.getActionType(),
                        stack,
                        pkt.getModifiedStacks()
                        );
            }
            break;
        }
        return packet;
    }

//	@Inject(method = "handlePacket(Lnet/minecraft/network/Packet;Lnet/minecraft/network/listener/PacketListener;)V", at = @At("HEAD"))
//	private static void logReceivedPacket(Packet<?> packet, PacketListener listener, CallbackInfo ci) {
//		PacketLogger.logReceivedPacket(packet, ((ClientConnectionAccessor) listener.getConnection()).getSide());
//	}
}
